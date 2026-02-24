
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionsCreated,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ra.UserId,
    ra.DisplayName,
    ra.QuestionsCreated,
    ra.UpVotesReceived,
    ra.DownVotesReceived,
    ub.BadgeNames,
    ub.BadgeCount,
    COALESCE(rp.Title, 'No posts') AS LastPostTitle,
    COALESCE(rp.ViewCount, 0) AS LastPostViewCount
FROM 
    RecentActivity ra
LEFT JOIN 
    UserBadges ub ON ra.UserId = ub.UserId
LEFT JOIN 
    RankedPosts rp ON ra.UserId = rp.OwnerUserId AND rp.UserPostRank = 1
WHERE 
    ra.QuestionsCreated > 0 
ORDER BY 
    ra.UpVotesReceived DESC, ra.QuestionsCreated DESC;
