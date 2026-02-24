WITH TagsSplit AS (
    SELECT 
        Id AS PostId,
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName
    FROM Posts
    WHERE Tags IS NOT NULL
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoters,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        AVG(u.Reputation) AS AvgUserReputation
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Users u ON v.UserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY p.Id
),
TagPopularity AS (
    SELECT 
        ts.TagName,
        COUNT(DISTINCT ps.PostId) AS PostCount,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.UniqueVoters) AS TotalUniqueVoters,
        AVG(ps.AvgUserReputation) AS AvgUserReputation
    FROM TagsSplit ts
    JOIN PostStatistics ps ON ts.PostId = ps.PostId
    GROUP BY ts.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalComments,
        TotalUniqueVoters,
        AvgUserReputation,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagPopularity
),
TrendingTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TrendingPostCount,
        SUM(TotalComments) AS TrendingTotalComments
    FROM TopTags
    WHERE TagRank <= 10  
    GROUP BY TagName
)

SELECT 
    tt.TagName,
    tt.PostCount,
    tt.TotalComments,
    tt.TotalUniqueVoters,
    tt.AvgUserReputation,
    tr.TrendingPostCount,
    tr.TrendingTotalComments
FROM TopTags tt
LEFT JOIN TrendingTags tr ON tt.TagName = tr.TagName
ORDER BY tt.PostCount DESC;