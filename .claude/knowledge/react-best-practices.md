# React Performance Best Practices

> Comprehensive performance optimization guide for React/Next.js applications.
> Source: Vercel Agent Skills - React Best Practices

---

## Priority Hierarchy

Performance optimizations ranked by impact:

1. **CRITICAL - Eliminating Waterfalls** - #1 performance killer
2. **CRITICAL - Bundle Size Optimization** - Affects TTI and LCP
3. **HIGH - Server-Side Performance** - Rendering and data fetching
4. **HIGH - Client-Side Data Fetching** - Deduplication and caching
5. **MEDIUM - Re-render Optimization** - Reduce unnecessary computation
6. **MEDIUM - Rendering Performance** - Browser rendering workload
7. **LOW-MEDIUM - JavaScript Performance** - Micro-optimizations
8. **LOW - Advanced Patterns** - Edge case techniques

---

## 1. Eliminating Waterfalls (CRITICAL)

### Parallel Async Operations
```tsx
// BAD - Sequential (3x slower)
const user = await fetchUser()
const posts = await fetchPosts()
const comments = await fetchComments()

// GOOD - Parallel (1x time)
const [user, posts, comments] = await Promise.all([
  fetchUser(),
  fetchPosts(),
  fetchComments()
])
```
**Impact:** 2-10x faster execution

### Defer Await Until Needed
```tsx
// BAD - Always waits even when not needed
async function handleAction(id: string) {
  const permissions = await fetchPermissions()  // Blocks early return
  const resource = await getResource(id)
  if (!resource) return { error: 'Not found' }
  // ...
}

// GOOD - Only fetch when actually needed
async function handleAction(id: string) {
  const resource = await getResource(id)
  if (!resource) return { error: 'Not found' }  // Early exit
  const permissions = await fetchPermissions()  // Only fetched if needed
  // ...
}
```

### Parallel Server Components
```tsx
// BAD - Waterfall: Sidebar waits for Page's fetch
async function Page() {
  const data = await fetchData()
  return (
    <Layout>
      <Sidebar />  {/* Waits for parent */}
    </Layout>
  )
}

// GOOD - Parallel fetching with sibling components
function Page() {
  return (
    <Layout>
      <Header />  {/* Fetches independently */}
      <Sidebar /> {/* Fetches independently */}
    </Layout>
  )
}
```

---

## 2. Bundle Size Optimization (CRITICAL)

### Dynamic Imports for Heavy Components
```tsx
// BAD - Bundles Monaco (~300KB) in main chunk
import { MonacoEditor } from './monaco-editor'

// GOOD - Lazy load on demand
const MonacoEditor = dynamic(
  () => import('./monaco-editor').then(m => m.MonacoEditor),
  { ssr: false }
)
```
**Impact:** Directly affects TTI and LCP

### Avoid Barrel File Imports
```tsx
// BAD - Loads entire library (200-800ms on cold start)
import { Check, X, Menu } from 'lucide-react'

// GOOD - Direct imports (15-70% faster dev startup)
import Check from 'lucide-react/dist/esm/icons/check'
import X from 'lucide-react/dist/esm/icons/x'
import Menu from 'lucide-react/dist/esm/icons/menu'

// BETTER - Use Next.js optimizedPackageImports (13.5+)
// next.config.js
module.exports = {
  experimental: {
    optimizePackageImports: ['lucide-react', '@heroicons/react']
  }
}
```
**Impact:** 15-70% faster dev startup, 28% faster builds, 40% faster cold starts

### Preload Based on User Intent
```tsx
// Preload on hover/focus (before click completes)
function EditorButton() {
  const preloadEditor = () => {
    if (typeof window !== 'undefined') {
      import('./heavy-editor')
    }
  }

  return (
    <button
      onMouseEnter={preloadEditor}
      onFocus={preloadEditor}
      onClick={openEditor}
    >
      Open Editor
    </button>
  )
}
```

---

## 3. Server-Side Performance (HIGH)

### React.cache() for Request Deduplication
```tsx
import { cache } from 'react'

// Deduplicated across components in same request
const getCurrentUser = cache(async () => {
  const session = await getSession()
  return db.user.findUnique({ where: { id: session.userId }})
})

// Call from multiple components - only one DB query per request
async function Header() {
  const user = await getCurrentUser()
  // ...
}

async function Sidebar() {
  const user = await getCurrentUser()  // Uses cached result
  // ...
}
```

### Minimize Serialization at RSC Boundaries
```tsx
// BAD - Serializes entire 50-field object
<ClientComponent user={user} />

// GOOD - Pass only needed fields
<ClientComponent userName={user.name} userAvatar={user.avatar} />
```
**Impact:** HIGH - Reduces data transfer size

---

## 4. Client-Side Data Fetching (HIGH)

### SWR for Automatic Deduplication
```tsx
// Multiple components calling this share one request
function useUser(id: string) {
  return useSWR(`/api/users/${id}`, fetcher)
}

// For static data that never changes
function useConfig() {
  return useSWRImmutable('/api/config', fetcher)
}

// For mutations
function useUpdateUser() {
  return useSWRMutation('/api/users', updateUser)
}
```

### Strategic Suspense Boundaries
```tsx
// BAD - Entire page waits for data
async function Page() {
  const data = await slowQuery()  // Blocks everything
  return <Layout><Content data={data} /></Layout>
}

// GOOD - Static shell renders immediately
function Page() {
  return (
    <Layout>
      <Suspense fallback={<Skeleton />}>
        <AsyncContent />  {/* Only this waits */}
      </Suspense>
    </Layout>
  )
}
```
**Avoid Suspense when:** Layout depends on data, SEO-critical above-fold content, queries are fast enough, layout shift is problematic

---

## 5. Re-render Optimization (MEDIUM)

### Extract to Memoized Components
```tsx
// BAD - Expensive work runs even during loading
function Profile({ userId, isLoading }) {
  const avatar = useMemo(() => generateAvatar(userId), [userId])

  if (isLoading) return <Spinner />  // Avatar still computed
  return <Avatar src={avatar} />
}

// GOOD - Skip computation entirely with early return
const MemoizedAvatar = memo(function Avatar({ userId }) {
  const avatar = useMemo(() => generateAvatar(userId), [userId])
  return <img src={avatar} />
})

function Profile({ userId, isLoading }) {
  if (isLoading) return <Spinner />  // No avatar computation
  return <MemoizedAvatar userId={userId} />
}
```

### Narrow Effect Dependencies
```tsx
// BAD - Re-runs on any user property change
useEffect(() => {
  trackUser(user.id)
}, [user])

// GOOD - Only re-runs when id changes
useEffect(() => {
  trackUser(userId)
}, [userId])

// GOOD - Derived boolean for threshold-based logic
const isMobile = width < 768
useEffect(() => {
  updateLayout(isMobile)
}, [isMobile])  // Only fires on mobile/desktop transition
```

### Subscribe to Derived State
```tsx
// BAD - Re-renders on every pixel change
const width = useWindowWidth()
const isMobile = width < 768

// GOOD - Only re-renders when crossing threshold
const isMobile = useMediaQuery('(max-width: 767px)')
```

### Lazy State Initialization
```tsx
// BAD - Runs on every render
const [index] = useState(buildExpensiveIndex(data))

// GOOD - Only runs once on mount
const [index] = useState(() => buildExpensiveIndex(data))
```
**Use for:** localStorage reads, building data structures, DOM reads, expensive transformations

### Use Transitions for Non-Urgent Updates
```tsx
// BAD - Scroll updates can block interactions
function ScrollTracker() {
  const [scrollY, setScrollY] = useState(0)

  useEffect(() => {
    const handler = () => setScrollY(window.scrollY)
    window.addEventListener('scroll', handler)
    return () => window.removeEventListener('scroll', handler)
  }, [])
}

// GOOD - Deprioritize scroll tracking
import { startTransition } from 'react'

function ScrollTracker() {
  const [scrollY, setScrollY] = useState(0)

  useEffect(() => {
    const handler = () => {
      startTransition(() => setScrollY(window.scrollY))
    }
    window.addEventListener('scroll', handler)
    return () => window.removeEventListener('scroll', handler)
  }, [])
}
```

---

## 6. Rendering Performance (MEDIUM)

### Hoist Static JSX
```tsx
// BAD - Recreated on every render
function List({ items }) {
  const skeleton = <div className="skeleton">...</div>  // New object each render
  // ...
}

// GOOD - Created once, reused
const SKELETON = <div className="skeleton">...</div>

function List({ items }) {
  if (!items) return SKELETON
  // ...
}
```
**Especially important for:** Large static SVG nodes

### Prevent Hydration Flicker
```tsx
// BAD - Flickers: renders default, then updates
function ThemeProvider({ children }) {
  const [theme, setTheme] = useState('light')
  useEffect(() => {
    setTheme(localStorage.getItem('theme') || 'light')
  }, [])
  // ...
}

// GOOD - Inline script sets theme before hydration
function ThemeProvider({ children }) {
  return (
    <div id="theme-wrapper">
      <script dangerouslySetInnerHTML={{
        __html: `
          (function() {
            const theme = localStorage.getItem('theme') || 'light';
            document.getElementById('theme-wrapper').className = theme;
          })();
        `
      }} />
      {children}
    </div>
  )
}
```

### Explicit Conditional Rendering
```tsx
// BAD - Renders "0" when count is 0
{count && <Badge>{count}</Badge>}

// GOOD - Renders nothing when count is 0
{count > 0 ? <Badge>{count}</Badge> : null}
```

### Activity Component for Expensive Toggles
```tsx
// For components that toggle frequently
import { Activity } from 'react'

function App() {
  const [showMenu, setShowMenu] = useState(false)

  return (
    <Activity mode={showMenu ? 'visible' : 'hidden'}>
      <ExpensiveMenu />  {/* State/DOM preserved when hidden */}
    </Activity>
  )
}
```

---

## 7. JavaScript Performance (LOW-MEDIUM)

### Use Set/Map for Lookups
```tsx
// BAD - O(n) per lookup
const allowed = allowedIds.filter(id => items.includes(id))

// GOOD - O(1) per lookup
const allowedSet = new Set(allowedIds)
const allowed = items.filter(item => allowedSet.has(item.id))
```

### Early Return from Functions
```tsx
// BAD - Continues processing after finding error
function validateUsers(users) {
  let hasError = false
  let firstError = null

  users.forEach(user => {
    if (!isValid(user)) {
      hasError = true
      firstError = firstError || user
    }
  })

  return { hasError, firstError }
}

// GOOD - Returns immediately
function validateUsers(users) {
  for (const user of users) {
    if (!isValid(user)) {
      return { hasError: true, firstError: user }
    }
  }
  return { hasError: false, firstError: null }
}
```

### Combine Multiple Iterations
```tsx
// BAD - 3 passes through array
const active = users.filter(u => u.active)
const admins = users.filter(u => u.role === 'admin')
const verified = users.filter(u => u.verified)

// GOOD - Single pass
const active = [], admins = [], verified = []
for (const user of users) {
  if (user.active) active.push(user)
  if (user.role === 'admin') admins.push(user)
  if (user.verified) verified.push(user)
}
```

### Cache Function Results
```tsx
// Module-level cache (works everywhere, not just components)
const cache = new Map<string, ProcessedData>()

function processData(key: string): ProcessedData {
  if (cache.has(key)) return cache.get(key)!

  const result = expensiveComputation(key)
  cache.set(key, result)
  return result
}
```

---

## 8. Advanced Patterns (LOW)

### useLatest for Stable Callbacks
```tsx
function useLatest<T>(value: T) {
  const ref = useRef(value)
  useEffect(() => {
    ref.current = value
  })
  return ref
}

// Usage: Access latest callback without adding to dependencies
function SearchInput({ onSearch }) {
  const onSearchRef = useLatest(onSearch)

  useEffect(() => {
    const handler = debounce(() => {
      onSearchRef.current(query)  // Always calls latest
    }, 300)
    // No need to add onSearch to deps, no cleanup on every render
  }, [query])
}
```

### Store Event Handlers in Refs
```tsx
function useEventListener(eventType, handler) {
  const handlerRef = useRef(handler)

  // Update ref when handler changes (no re-subscription)
  useEffect(() => {
    handlerRef.current = handler
  })

  // Stable subscription (only depends on eventType)
  useEffect(() => {
    const listener = (e) => handlerRef.current(e)
    window.addEventListener(eventType, listener)
    return () => window.removeEventListener(eventType, listener)
  }, [eventType])
}
```

---

## Quick Reference

| Problem | Solution | Impact |
|---------|----------|--------|
| Sequential fetches | `Promise.all()` | CRITICAL |
| Heavy components in bundle | `next/dynamic` | CRITICAL |
| Barrel file imports | Direct imports or `optimizePackageImports` | HIGH |
| Duplicate server queries | `React.cache()` | HIGH |
| Duplicate client requests | SWR/React Query | HIGH |
| Expensive computations | Extract to memoized component | MEDIUM |
| Frequent re-renders | Narrow dependencies, derived state | MEDIUM |
| Static JSX recreation | Hoist outside component | MEDIUM |
| Hydration flicker | Inline script before content | MEDIUM |
| O(n) lookups | Set/Map data structures | LOW-MEDIUM |
| Full array processing | Early returns | LOW |

---

## Anti-Patterns to Avoid

1. **Awaiting in sequence** when operations are independent
2. **Importing from barrel files** (index.js re-exports)
3. **Passing entire objects** across RSC boundaries
4. **Object/array deps** in useEffect when primitives suffice
5. **useState with computed value** instead of function
6. **Using && with numbers** for conditional rendering
7. **Handler functions in deps** causing re-subscriptions
8. **Computing during loading** states that exit early
