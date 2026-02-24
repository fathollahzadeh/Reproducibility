WITH Tag_List AS (
    SELECT 
        split_part(tag, '>', 1) AS TagName,
        COUNT(*) AS TagCount
    FROM (
        SELECT 
            unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS tag,
            Id
        FROM Posts
        WHERE PostTypeId = 1  
    ) AS Tags_Sub
    GROUP BY TagName
),
Active_Users AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY u.Id, u.DisplayName
),
Top_Tags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM Tag_List
    WHERE TagCount > 5  
)
SELECT 
    au.DisplayName AS ActiveUser,
    au.PostCount AS NumberOfPosts,
    au.UpVotes AS TotalUpVotes,
    au.DownVotes AS TotalDownVotes,
    tt.TagName AS MostUsedTag,
    tt.TagCount AS UsageCount
FROM Active_Users au
JOIN Top_Tags tt ON TRUE  
WHERE au.UpVotes > 10  
ORDER BY au.PostCount DESC, tt.TagCount DESC
LIMIT 10;