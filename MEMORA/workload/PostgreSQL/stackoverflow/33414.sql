
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
),
MostActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users U
    JOIN 
        Posts p ON U.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5 
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),
TopClosedPosts AS (
    SELECT 
        cp.PostId,
        cp.CloseReason,
        cp.CreationDate AS CloseDate,
        ROW_NUMBER() OVER (PARTITION BY cp.PostId ORDER BY cp.CloseRank ASC) AS rn
    FROM 
        ClosedPosts cp
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.OwnerDisplayName,
    m.UserId AS ActiveUserId,
    m.DisplayName AS ActiveUserName,
    tc.CloseReason,
    tc.CloseDate
FROM 
    RankedPosts r
LEFT JOIN 
    MostActiveUsers m ON r.OwnerUserId = m.UserId
LEFT JOIN 
    TopClosedPosts tc ON r.PostId = tc.PostId AND tc.rn = 1
WHERE 
    r.ScoreRank <= 3 
ORDER BY 
    r.Score DESC, 
    r.CreationDate ASC;
