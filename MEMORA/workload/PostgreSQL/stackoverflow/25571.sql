
WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Users.Reputation) AS AvgReputation,
        COUNT(DISTINCT Users.Id) AS UserCount
    FROM 
        Tags
    JOIN 
        Posts ON Posts.Tags LIKE CONCAT('%<', Tags.TagName, '>%' ) 
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    GROUP BY 
        Tags.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AvgReputation,
        UserCount,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TagStats
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AvgReputation,
        UserCount
    FROM 
        TopTags
    WHERE 
        ViewRank <= 10
),
UserBadges AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Badges.Id) AS BadgeCount,
        SUM(CASE WHEN Badges.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN Badges.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN Badges.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    GROUP BY 
        Users.Id, Users.DisplayName
),
TopUsers AS (
    SELECT 
        DisplayName,
        BadgeCount,
        GoldCount,
        SilverCount,
        BronzeCount,
        RANK() OVER (ORDER BY BadgeCount DESC) AS BadgeRank
    FROM 
        UserBadges
    WHERE 
        BadgeCount > 0
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.TotalViews,
    tt.AvgReputation,
    uu.DisplayName AS TopUser,
    uu.BadgeCount,
    uu.GoldCount,
    uu.SilverCount,
    uu.BronzeCount
FROM 
    PopularTags tt
JOIN 
    TopUsers uu ON uu.BadgeRank = 1
ORDER BY 
    tt.TotalViews DESC;
