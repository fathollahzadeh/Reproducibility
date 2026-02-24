
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(co.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Comments co ON u.Id = co.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        p.Title
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
        AND p.Score IS NOT NULL
)
SELECT 
    rp.Title AS TopPostTitle,
    rp.RankScore,
    ue.DisplayName AS EngagingUser,
    ue.CommentCount,
    ue.TotalBounties,
    phd.Comment AS HistoryComment,
    phd.CreationDate AS HistoryDate
FROM 
    RankedPosts rp
JOIN 
    UserEngagement ue ON ue.CommentCount > 0
LEFT JOIN 
    PostHistoryDetails phd ON phd.PostId = rp.PostId
WHERE 
    rp.RankScore <= 5
ORDER BY 
    rp.Score DESC, ue.TotalBounties DESC;
