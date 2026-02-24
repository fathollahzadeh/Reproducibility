
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        pt.Name AS PostType
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.PostId) AS TotalVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        AVG(p.ViewCount) AS AvgPostViews
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostWithBadges AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(b.Id) AS BadgeCount,
        CASE 
            WHEN COUNT(b.Id) > 0 THEN 'Has badges' 
            ELSE 'No badges' 
        END AS BadgeStatus
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.OwnerUserId IS NOT NULL
    GROUP BY 
        p.Id, p.Title
),
CombinedResults AS (
    SELECT 
        rp.Title,
        rp.PostId,
        rp.Score,
        rp.ViewCount,
        ua.DisplayName AS UserName,
        ua.TotalVotes,
        ua.Upvotes,
        ua.Downvotes,
        ua.AvgPostViews,
        pb.BadgeCount,
        pb.BadgeStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserActivity ua ON rp.PostId IN (SELECT PostId FROM Votes WHERE UserId = ua.UserId)
    LEFT JOIN 
        PostWithBadges pb ON rp.PostId = pb.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    *,
    CASE 
        WHEN AvgPostViews IS NULL THEN 'No data'
        ELSE CONCAT('Average views: ', AvgPostViews)
    END AS ViewInfo,
    CASE 
        WHEN Upvotes > Downvotes THEN 'Positive engagement'
        ELSE 'Negative engagement'
    END AS EngagementStatus
FROM 
    CombinedResults
ORDER BY 
    Score DESC, UserName ASC;
