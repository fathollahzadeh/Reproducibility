
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.Id IS NOT NULL THEN v.Id END) AS VoteCount,
        COUNT(DISTINCT CASE WHEN b.Id IS NOT NULL THEN b.Id END) AS BadgeCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        MAX(p.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN p.Id IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostPerformance AS (
    SELECT 
        ps.PostId,
        ps.CommentCount,
        ps.VoteCount,
        ps.BadgeCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        us.UserId,
        us.PostCount,
        us.GoldBadgeCount,
        us.SilverBadgeCount,
        us.BronzeBadgeCount,
        ps.LastActivityDate,
        RANK() OVER (ORDER BY ps.UpVoteCount DESC, ps.CommentCount DESC) AS OverallRank
    FROM 
        PostStats ps
    JOIN 
        Posts p ON ps.PostId = p.Id  
    JOIN 
        UserStats us ON p.OwnerUserId = us.UserId
    WHERE 
        ps.LastActivityDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
)
SELECT 
    p.PostId,
    p.CommentCount,
    p.VoteCount,
    p.UpVoteCount,
    p.DownVoteCount,
    p.PostCount AS UserPostCount,
    p.GoldBadgeCount,
    p.SilverBadgeCount,
    p.BronzeBadgeCount,
    p.LastActivityDate,
    p.OverallRank
FROM 
    PostPerformance p
WHERE 
    p.OverallRank <= 100
ORDER BY 
    p.OverallRank;
