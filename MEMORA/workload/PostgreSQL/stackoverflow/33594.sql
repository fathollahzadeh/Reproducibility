
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > DATE('2024-10-01') - INTERVAL '30 days'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(rb.BadgeCount, 0) AS BadgeCount,
        COALESCE(rb.BadgeNames, 'No Badges') AS Badges,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        RANK() OVER (ORDER BY COALESCE(SUM(p.ViewCount), 0) DESC) AS RankByViews
    FROM 
        Users u
    LEFT JOIN 
        RecentPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        UserBadges rb ON u.Id = rb.UserId
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, rb.BadgeCount, rb.BadgeNames
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    u.BadgeCount,
    u.Badges,
    rp.PostId,
    p.Title,
    p.CreationDate,
    e.CommentCount,
    e.UpVoteCount,
    e.DownVoteCount,
    e.NetVotes,
    u.RankByViews
FROM 
    TopUsers u
JOIN 
    RecentPosts rp ON u.UserId = rp.OwnerUserId
JOIN 
    PostEngagement e ON rp.PostId = e.PostId
JOIN 
    Posts p ON rp.PostId = p.Id
WHERE 
    u.RankByViews <= 10
ORDER BY 
    u.RankByViews, rp.CreationDate DESC;
