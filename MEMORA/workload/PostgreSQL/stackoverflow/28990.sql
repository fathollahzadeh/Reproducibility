
WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AvgUserReputation,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 0
),
PopularUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS QuestionsAnswered,
        SUM(p.ViewCount) AS ReputationBoost
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 2 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(p.Id) > 5 AND u.Reputation > 100
),
CombinedData AS (
    SELECT 
        tt.TagName,
        tt.PostCount,
        tt.TotalViews,
        tt.AvgUserReputation,
        pu.UserId,
        pu.DisplayName,
        pu.Reputation
    FROM 
        TopTags tt
    JOIN 
        PopularUsers pu ON pu.Reputation > tt.AvgUserReputation
)
SELECT 
    cd.TagName,
    cd.PostCount,
    cd.TotalViews,
    cd.AvgUserReputation,
    cd.DisplayName,
    cd.Reputation
FROM 
    CombinedData cd
ORDER BY 
    cd.TotalViews DESC, cd.AvgUserReputation DESC
LIMIT 10;
