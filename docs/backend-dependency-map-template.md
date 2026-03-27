# Backend Dependency Map

> **Purpose**: Identify the full blast radius when modifying any table, function, or policy.
> MUST be referenced before all backend work. The `/preflight` skill reads this document automatically.

---

## Domain Classification

<!-- Define your project's domains. Group related tables/resources together. -->

```
┌─────────────────────────────────────────────────┐
│                 YOUR PROJECT                     │
├──────────┬──────────┬──────────┬────────────────┤
│ Domain 1 │ Domain 2 │ Domain 3 │ Domain 4       │
├──────────┼──────────┼──────────┼────────────────┤
│ table_a  │ table_d  │ table_g  │ table_j        │
│ table_b  │ table_e  │ table_h  │ table_k        │
│ table_c  │ table_f  │ table_i  │                │
└──────────┴──────────┴──────────┴────────────────┘
```

---

## Per-Table Dependency Map

<!-- Copy this template for each table in your project. -->

### {table_name}

| Dependency | Name | Notes |
|------------|------|-------|
| **Access Policy** | {policy_name} ({operation}, {condition}) | |
| **Trigger** | {trigger_name} | {what it protects/does} |
| **Function (read)** | {func1}, {func2} | |
| **Function (write)** | {func3}, {func4} | |
| **View** | {view_name} | |
| **Server Function** | {endpoint_name} ({what it does}) | |
| **Client Service** | {ServiceName} ({how it queries}) | |
| **Real-time** | {ProviderName} ({event type}) | |
| **FK targets** | {other_table.column} (CASCADE/RESTRICT) | |

> **When changing {table_name} columns**: {describe what else must be checked}

---

<!-- Repeat for each table -->

---

## Cross-Domain Impact Chains

<!-- Document how changes in one domain propagate to others. -->

### Chain 1: {Domain A} → {Domain B}
```
{table} column change
  → {function} ({table} JOIN) breaks
  → {client provider} returns empty/error
  → {screen} failure
```

### Chain 2: {Domain A} → {Domain C}
```
{table} column change
  → {view} breaks
  → {server function} error
  → {external system} failure
```

<!-- Add more chains as you discover them -->

---

## Server Function Dependency Map

<!-- Document each server-side function/endpoint and its dependencies. -->

| Function | Read Tables | Write Tables | Called Functions | External APIs | Called From |
|----------|-------------|-------------|-----------------|---------------|------------|
| **{func1}** | {tables} | {tables} | {rpcs} | {apis} | {caller} |
| **{func2}** | {tables} | {tables} | {rpcs} | {apis} | {caller} |

---

## Real-time Subscription Map

<!-- Document all real-time subscriptions. -->

| Provider | Table | Event | Channel Pattern | Caution |
|----------|-------|-------|-----------------|---------|
| {Provider1} | {table} | {INSERT/UPDATE/DELETE} | {pattern} | {what to watch for} |

> **When changing columns on real-time subscribed tables**: Client payload structure changes. Provider parsing logic must be updated.

---

## Index Map

<!-- Document performance-critical indexes. -->

| Table | Index | Columns | Condition | Used By |
|-------|-------|---------|-----------|---------|
| {table} | {idx_name} | {columns} | {partial condition} | {query/feature} |
