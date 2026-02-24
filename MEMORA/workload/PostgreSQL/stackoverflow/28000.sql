
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalQuestions,
    us.TotalBadges,
    us.TotalScore,
    us.TotalViews,
    rp.PostId,
    rp.Title AS MostRecentQuestionTitle,
    rp.CreationDate AS MostRecentQuestionDate,
    rp.Score AS MostRecentQuestionScore,
    rp.ViewCount AS MostRecentQuestionViews,
    ra.PostId AS RecentActivityPostId,
    ra.Title AS RecentActivityTitle,
    ra.CreationDate AS RecentActivityDate,
    ra.UserDisplayName AS RecentActivityUser,
    ra.Comment AS RecentActivityComment,
    pt.TagName AS PopularTag,
    pt.TagCount AS PopularTagCount
FROM 
    UserStatistics us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN 
    RecentActivity ra ON ra.PostId = rp.PostId
CROSS JOIN 
    PopularTags pt
ORDER BY 
    us.Reputation DESC, us.TotalScore DESC;
