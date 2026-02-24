
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.TAGS,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.TAGS
),
TopUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.Reputation,
        ue.TotalBounty,
        RANK() OVER (ORDER BY ue.TotalBounty DESC) AS BountyRank
    FROM 
        UserEngagement ue
    WHERE 
        ue.TotalPosts > 0
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.CommentCount,
        ps.HistoryCount,
        ps.UserPostRank,
        RANK() OVER (ORDER BY ps.Score DESC, ps.CommentCount DESC) AS PostRank
    FROM 
        PostStats ps
),
CombinedStats AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.Reputation,
        tu.TotalBounty,
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.CommentCount,
        tp.HistoryCount,
        tu.BountyRank,
        tp.PostRank
    FROM 
        TopUsers tu
    INNER JOIN 
        TopPosts tp ON tp.UserPostRank = 1 AND tu.UserId = (SELECT OwnerUserId FROM Posts ORDER BY CreationDate DESC LIMIT 1)
)
SELECT 
    cs.UserId,
    cs.DisplayName,
    cs.Reputation,
    cs.TotalBounty,
    cs.Title,
    cs.Score,
    cs.CommentCount,
    cs.HistoryCount,
    cs.BountyRank,
    cs.PostRank,
    CASE 
        WHEN cs.Score IS NULL THEN 'No Score Yet'
        WHEN cs.Score > 10 THEN 'Highly Rated'
        ELSE 'Moderately Rated'
    END AS RatingStatus,
    CONCAT('User: ', cs.DisplayName, ' (Reputation: ', cs.Reputation, ') - Post Title: ', cs.Title) AS UserPostComment
FROM 
    CombinedStats cs
WHERE 
    cs.PostRank <= 10 OR cs.BountyRank <= 10
ORDER BY 
    cs.BountyRank ASC,
    cs.PostRank ASC;
