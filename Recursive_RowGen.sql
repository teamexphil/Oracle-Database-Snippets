WITH InfiniteRows (RowNumber) AS (
   -- Anchor member definition
   SELECT 1 AS RowNumber
   FROM DUAL
   UNION ALL
   -- Recursive member definition
   SELECT a.RowNumber + 1    AS RowNumber
   FROM   InfiniteRows a
   WHERE  a.RowNumber < 10
)
-- Statement that executes the CTE
SELECT RowNumber
FROM   InfiniteRows;
