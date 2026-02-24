
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATE('2024-10-01') - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        COALESCE(NULLIF(SUM(CASE WHEN b.TagBased THEN 1 ELSE 0 END), 0), -1) AS TagBasedBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentVoting AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= DATE('2024-10-01') - INTERVAL '30 days' 
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    ur.DisplayName AS OwnerName,
    ur.TotalBadges,
    ur.TagBasedBadges,
    rv.VoteCount,
    COALESCE(rv.UpVotes, 0) AS UpVotes,
    COALESCE(rv.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN rp.PostRank = 1 AND rv.VoteCount > 10 THEN 'Hot Post'
        WHEN rp.PostRank = 1 AND rv.VoteCount <= 10 THEN 'Trending Post'
        ELSE 'Regular Post' 
    END AS PostCategory,
    CASE 
        WHEN rp.CommentCount IS NULL THEN 'No Comments Yet'
        WHEN rp.CommentCount > 5 THEN 'Highly Discussed'
        ELSE 'Moderately Discussed' 
    END AS DiscussionStatus
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    RecentVoting rv ON rv.PostId = rp.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.CommentCount DESC, ur.TotalBadges DESC
LIMIT 10;
