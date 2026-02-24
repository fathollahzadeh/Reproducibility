
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentPostsRanking
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
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
PostWithComments AS (
    SELECT 
        p.Title,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Title
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.AnswerCount,
    ur.DisplayName,
    ur.Reputation,
    ur.TotalUpVotes,
    ur.BadgeCount,
    COALESCE(pwc.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN rp.RecentPostsRanking = 1 THEN 'Recent'
        ELSE 'Not Recent'
    END AS PostStatus
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON ur.UserId = rp.PostId 
LEFT JOIN 
    PostWithComments pwc ON rp.Title = pwc.Title
WHERE 
    rp.ViewCount > 100
    AND ur.Reputation > 50
ORDER BY 
    rp.ViewCount DESC, 
    ur.Reputation DESC;
