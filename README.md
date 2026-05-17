## The Vision
In the modern era of software engineering, database schemas often become "black boxes" accumulating technical debt, hidden bottlenecks, and security vulnerabilities. **AI Database Analyzer** is an enterprise-grade architectural intelligence tool designed to bridge the gap between raw database schemas and actionable expert insights. 

Built with **.NET MAUI** and strict **Senior-level MVVM architectures**, this tool doesn't just read your database—it audits it like a Senior Database Administrator. By leveraging **Hybrid AI (Google Gemini Cloud & Ollama Local)**, we transform complex metadata into strategic roadmaps, ensuring your data layer is scalable, secure, and highly performant before a single line of application code goes to production.

## Key Features
* **Deep Metadata Extraction:** Native support for SQL Server, PostgreSQL, and MySQL.
* **Hybrid AI Support:** Toggle instantly between local, privacy-first analysis (Ollama) and high-scale cloud intelligence (Gemini).
* **Interactive ER Visualization:** Live, zoomable, and clickable ER diagrams powered by Mermaid.js and SVG-Pan-Zoom.
* **Professional PDF Reporting:** Export comprehensive, executive-level analysis reports via QuestPDF.
* **Secure & Clean Architecture:** 100% MVVM, Dependency Injection, and industry-standard protection for API keys via SecureStorage.

## Architectural Intelligence Suite
The analyzer comes equipped with 30+ specialized prompts that audit your database across critical pillars:

### Performance & Indexing
* **Non-SARGable Query Predicates & Missing Indexes:** Detects hidden query performance traps and high-cardinality columns lacking B-Tree indexes.
* **Over-indexing & Overlapping Costs:** Identifies redundant composite indexes that bloat storage and slow down DML operations.
* **Trigger-Induced Bottlenecks:** Analyzes recursive loops and deadlock risks caused by triggers executing during concurrent updates.
* **Execution Plan Simulation:** Mentally simulates execution plans (Hash Match, Nested Loops) for critical queries to predict bottlenecks.
* **Foreign Key Index Deficiency:** Reports unindexed foreign keys that cause expensive, hidden full table scans during cascading deletes.
* **Heap Table & Primary Key Analysis:** Identifies tables lacking Clustered Indexes and explains physical fragmentation risks.

### Schema Design & Data Modeling
* **Bloated Records & Data Type Wastage:** Compares column types against random data samples to find storage waste (e.g., 255-chars for booleans).
* **Normalization Violations (3NF):** Detects transitive dependencies and repeating data groups within rows.
* **Poorly Designed Denormalization:** Audits duplicated data points for synchronization risks and lack of consistency guarantees.
* **Orphan Records Detection:** Finds missing logical relationships that lack physical foreign key constraints.
* **Circular Dependency Mapping:** Uses graph-based routing to detect infinite loops in database architecture.
* **Hidden Complexity in Views:** Audits excessive nesting and suggests Common Table Expressions (CTEs) or materialized views.
* **Recursive CTE Misusage:** Investigates the absence of depth constraints to prevent recursive depth overflows.
* **Siloed Schema Modules:** Groups tables into business domains (DDD) and identifies non-integrated database silos.
* **Data Type Inconsistency:** Finds identical columns across tables with conflicting data types (implicit conversion risks).
* **Table Width & Page Fragmentation:** Flags wide tables that risk exceeding physical 8KB page limits (Row-chaining).
* **Identity Column Capacity Audit:** Warns against capacity exhaustion when using `TINYINT` or `SMALLINT` for highly active primary keys.
* **Naming Standards:** Reviews CamelCase/snake_case consistency across tables and columns.
* **Automated Data Dictionary:** Generates Markdown documentation explaining the business purpose of each table.

### Security, Privacy & Integrity
* **RBAC & Least Privilege Violations:** Audits permission tables to detect erroneous direct access to critical system entities.
* **Sensitive Data (PII/PHI) Encryption:** Uses NER logic to find unmasked identification, health, or financial records lacking encryption at rest.
* **Over-reliance on Client-Side Controls:** Identifies missing `CHECK` constraints, highlighting business logic vulnerabilities.
* **Privilege Escalation (IDOR):** Assesses the risk of using predictable sequential integers (auto-increment) instead of UUIDs for external services.
* **Dynamic Procedures & SQL Injection:** Inspects stored procedures for unsanitized inputs and Second-Order SQLi risks.
* **Double Spending & Race Conditions:** Audits wallet/inventory tables for the absence of Optimistic or Pessimistic locking columns (versioning).
* **Missing Audit Trails:** Detects sensitive tables lacking CDC or auditing columns (`created_at`, `updated_by`).
* **GDPR/HIPAA Data Retention:** Checks for the absence of mechanisms (Time-to-Live, soft deletes) dictating when data must be anonymized.
* **Format Bypass (Data Poisoning):** Locates fields (email, IP) lacking Regex/Domain validation constraints.
* **AI Model Collapse Detection:** Scans sample data for synthetic pollution generated by LLMs to verify model training suitability.
* **Polymorphic Relationship Flaws:** Analyzes dual-column combinations (`entity_id` / `entity_type`) for referential integrity loss.
* **Soft Delete Consistency:** Highlights reporting inaccuracies caused by non-uniform deletion logic (`IsDeleted`, `StatusID`).
* **Excessive Nullability:** Audits tables where business-critical columns allow `NULL` without corresponding constraints.

### 🚀 Scalability & Architecture
* **Horizontal Scalability Bottlenecks:** Evaluates foreign key bindings to identify tables suitable for partition keys in a microservices transition.
* **Improper Time-Series Storage:** Explains why storing high-frequency logs/metrics in relational B-Tree schemas cripples write performance.
* **ORM Anti-Patterns:** Detects fragmented designs prone to generating N+1 query problems in backend integrations.
* **Collation Mismatches:** Detects character set differences between joined tables that invalidate indexes.
* **Connection Pool Exhaustion:** Analyzes metadata, sessions, and temp table logic for flaws that bloat connection pools.
* **Platform Migration Risk:** Identifies proprietary engine-specific dependencies complicating moves to open-source or cloud-native DBs.
* **Microservice Boundary Grouping:** Suggests logical data boundaries to decompose monolithic schemas.

---

