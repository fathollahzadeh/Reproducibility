
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(pb.BadgeCount, 0) AS BadgeCount,
        COALESCE(pp.UpVotes, 0) AS UpVotes,
        COALESCE(pp.DownVotes, 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        UserBadges pb ON u.Id = pb.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostVoteCounts pp ON p.Id = pp.PostId
    GROUP BY 
        u.Id, u.DisplayName, pb.BadgeCount, pp.UpVotes, pp.DownVotes
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.BadgeCount,
    up.UpVotes,
    up.DownVotes,
    up.PostCount,
    up.TotalViews,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore
FROM 
    UserPostStats up
LEFT JOIN 
    RankedPosts rp ON up.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId LIMIT 1)
WHERE 
    up.BadgeCount > 0
ORDER BY 
    up.TotalViews DESC
LIMIT 10;
