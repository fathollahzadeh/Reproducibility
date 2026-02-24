
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
ClosedPosts AS (
    SELECT 
        p.Title,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment 
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
),
CombinedData AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.AnswerCount,
        u.TotalScore,
        u.TotalPosts,
        cp.UserDisplayName AS ClosedBy
    FROM 
        RankedPosts r
    LEFT JOIN 
        TopUsers u ON r.Rank = 1 AND r.PostId IN (SELECT PostId FROM Comments WHERE UserId = u.UserId)
    LEFT JOIN 
        ClosedPosts cp ON r.Title = cp.Title
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    TotalScore,
    TotalPosts,
    COALESCE(ClosedBy, 'Not Closed') AS ClosedBy
FROM 
    CombinedData
WHERE 
    TotalScore IS NOT NULL
ORDER BY 
    TotalScore DESC, CreationDate DESC
LIMIT 10;
