
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS GlobalRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),

UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AvgPostScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10) THEN ph.CreationDate END) AS CloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (11) THEN ph.CreationDate END) AS ReopenDate,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 12) THEN ph.Id END) AS CloseVoteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    u.DisplayName,
    ups.TotalPosts,
    ups.TotalScore,
    ups.AvgPostScore,
    ups.AvgViewCount,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.ViewCount,
    pp.AnswerCount,
    pp.CommentCount,
    CASE 
        WHEN phd.CloseDate IS NOT NULL THEN 'Closed'
        WHEN phd.ReopenDate IS NOT NULL THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus,
    phd.CloseVoteCount,
    COALESCE(rp.PostRank, 0) AS OwnerPostRank,
    COALESCE(rp.GlobalRank, 0) AS GlobalPostRank
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserId = u.Id
JOIN 
    Posts pp ON u.Id = pp.OwnerUserId AND pp.PostTypeId = 1
LEFT JOIN 
    PostHistoryDetails phd ON pp.Id = phd.PostId
LEFT JOIN 
    RankedPosts rp ON pp.Id = rp.PostId
WHERE 
    ups.AvgPostScore > COALESCE((SELECT AVG(AvgPostScore) FROM UserPostStats), 0)
    AND pp.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
ORDER BY 
    ups.TotalScore DESC, pp.ViewCount DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
