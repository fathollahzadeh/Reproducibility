
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(v.UserId, 0)) AS VotesReceived
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  
    GROUP BY u.Id, u.DisplayName
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount
    FROM Comments c
    WHERE c.CreationDate >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY c.PostId
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        ra.DisplayName AS OwnerDisplayName,
        COALESCE(rc.CommentCount, 0) AS RecentCommentCount
    FROM RankedPosts rp
    JOIN UserActivity ra ON rp.OwnerUserId = ra.UserId
    LEFT JOIN RecentComments rc ON rp.PostId = rc.PostId
    WHERE rp.OwnerPostRank = 1  
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.OwnerDisplayName,
    ps.RecentCommentCount,
    CASE 
        WHEN ps.RecentCommentCount > 0 THEN 'Active Discussion'
        ELSE 'No Recent Activity'
    END AS DiscussionStatus
FROM PostSummary ps
WHERE ps.Score >= (SELECT AVG(Score) FROM Posts)  
ORDER BY ps.Score DESC, ps.ViewCount DESC
LIMIT 10 OFFSET 0;