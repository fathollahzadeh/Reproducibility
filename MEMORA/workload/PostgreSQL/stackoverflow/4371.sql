
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        PH.CreationDate AS ClosedDate,
        EXTRACT(EPOCH FROM (PH.CreationDate - p.CreationDate)) / 60 AS DurationUntilClosed
    FROM 
        Posts p
    JOIN 
        PostHistory PH ON p.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10 
),
TopTags AS (
    SELECT 
        t.Id,
        t.TagName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%' 
    GROUP BY 
        t.Id, t.TagName
    HAVING 
        SUM(p.ViewCount) > 1000
),
RankedUserStats AS (
    SELECT 
        us.*,
        COALESCE(cp.Count, 0) AS ClosedPostCount
    FROM 
        UserStats us
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS Count FROM ClosedPosts GROUP BY UserId) AS cp ON us.UserId = cp.UserId
)
SELECT 
    ru.DisplayName,
    ru.PostCount,
    ru.ClosedPostCount,
    tt.TagName,
    tt.TotalViews
FROM 
    RankedUserStats ru
CROSS JOIN 
    TopTags tt
WHERE 
    ru.PostCount > 5
    AND tt.PostCount > 2
    AND ru.TotalBounty > 50
ORDER BY 
    ru.PostRank ASC, tt.TotalViews DESC;
