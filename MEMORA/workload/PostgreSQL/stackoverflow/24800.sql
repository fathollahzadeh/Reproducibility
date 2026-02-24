
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        p.Score,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
PostStatistics AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT rp.OwnerUserId) AS UniqueOwners,
        SUM(rp.UpVoteCount) AS TotalUpVotes,
        SUM(rp.DownVoteCount) AS TotalDownVotes,
        AVG(rp.Score) AS AvgScore,
        STRING_AGG(DISTINCT rp.Title, '; ') AS PostTitles,
        SUM(CASE 
            WHEN rp.CommentCount > 0 THEN 1 
            ELSE 0 
        END) AS PostsWithComments
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        ARRAY_AGG(b.Name) AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FinalResults AS (
    SELECT 
        ps.OwnerUserId,
        ps.TotalPosts,
        ps.UniqueOwners,
        ps.TotalUpVotes,
        ps.TotalDownVotes,
        ps.AvgScore,
        ub.BadgeNames,
        ub.BadgeCount
    FROM 
        PostStatistics ps
    LEFT JOIN 
        UserBadges ub ON ps.OwnerUserId = ub.UserId
)

SELECT 
    f.OwnerUserId,
    f.TotalPosts,
    f.UniqueOwners,
    f.TotalUpVotes,
    f.TotalDownVotes,
    f.AvgScore,
    COALESCE(f.BadgeNames, ARRAY[NULL]) AS BadgeNames,
    COALESCE(f.BadgeCount, 0) AS BadgeCount
FROM 
    FinalResults f
WHERE 
    f.TotalPosts > 10
ORDER BY 
    f.AvgScore DESC
FETCH FIRST 10 ROWS ONLY;
