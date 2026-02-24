
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATE('2024-10-01') - INTERVAL '1 year'
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        CASE 
            WHEN SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) THEN 'More Upvotes'
            WHEN SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) < SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) THEN 'More Downvotes'
            ELSE 'Equal Votes'
        END AS VoteBalance
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerUserId, u.DisplayName, rp.CreationDate, rp.Score
    HAVING 
        COUNT(c.Id) > 5 AND rp.Score > 0
),
RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        b.Date,
        DENSE_RANK() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS Rank
    FROM 
        Badges b
    WHERE 
        b.Date >= DATE('2024-10-01') - INTERVAL '6 months'
),
UserRanking AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.CreationDate IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalVotes,
        CASE 
            WHEN COALESCE(SUM(v.BountyAmount), 0) > 100 THEN 'Gold Star Contributor'
            WHEN COALESCE(SUM(v.BountyAmount), 0) > 50 THEN 'Silver Star Contributor'
            ELSE 'Bronze Contributor'
        END AS ContributionLevel
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    pp.Title,
    pp.OwnerDisplayName,
    pp.CreationDate,
    pp.Score,
    pp.CommentCount,
    pp.UpvoteCount,
    pp.DownvoteCount,
    pp.VoteBalance,
    ub.DisplayName AS ContributionUser,
    ub.TotalBounty,
    ub.ContributionLevel,
    rb.BadgeName
FROM 
    PopularPosts pp
LEFT JOIN 
    UserRanking ub ON pp.OwnerUserId = ub.UserId
LEFT JOIN 
    RecentBadges rb ON pp.OwnerUserId = rb.UserId AND rb.Rank = 1
WHERE 
    pp.Score BETWEEN 10 AND 500
ORDER BY 
    pp.Score DESC, pp.CommentCount DESC, pp.CreationDate ASC;
