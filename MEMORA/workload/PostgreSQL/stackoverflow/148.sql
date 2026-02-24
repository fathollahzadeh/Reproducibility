
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostInteractions AS (
    SELECT
        p.Id AS PostId,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount,
        COALESCE(ph.ClosedCount, 0) AS ClosedCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS ClosedCount 
        FROM 
            PostHistory 
        WHERE 
            PostHistoryTypeId = 10 
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    up.TotalBounty,
    up.BadgeCount,
    pp.Title,
    pp.CreationDate AS PostDate,
    pp.Score,
    pp.ViewCount,
    pp.AnswerCount,
    pp.CommentCount,
    pi.CommentCount AS InteractionsCommentCount,
    pi.UpVoteCount,
    pi.DownVoteCount,
    pi.ClosedCount,
    CASE 
        WHEN pi.ClosedCount > 0 THEN 'Closed'
        WHEN pp.AnswerCount > 0 AND pp.Score IS NOT NULL THEN 'Answered'
        ELSE 'Unanswered'
    END AS PostStatus
FROM 
    UserStats up
INNER JOIN 
    RankedPosts pp ON up.UserId = pp.Id
LEFT JOIN 
    PostInteractions pi ON pp.Id = pi.PostId
WHERE 
    pp.PostRank <= 5  
ORDER BY 
    up.Reputation DESC, pp.CreationDate DESC;
