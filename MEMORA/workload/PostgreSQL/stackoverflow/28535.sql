
WITH TagCounts AS (
    SELECT unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
           COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1 
    GROUP BY unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))
),
TopTags AS (
    SELECT TagName,
           PostCount,
           ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM TagCounts
    WHERE PostCount > 1
),
TopUsers AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           SUM(U.UpVotes) AS TotalUpVotes,
           SUM(U.DownVotes) AS TotalDownVotes,
           COUNT(B.Id) AS BadgeCount,
           ROW_NUMBER() OVER (ORDER BY SUM(U.UpVotes) DESC) AS UserRank
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PopularPosts AS (
    SELECT P.Id,
           P.Title,
           P.Score,
           P.ViewCount,
           P.CreationDate,
           U.DisplayName AS OwnerDisplayName,
           ARRAY_AGG(DISTINCT T.TagName) AS Tags
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    JOIN TagCounts T ON T.TagName = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><'))
    WHERE P.PostTypeId = 1
    GROUP BY P.Id, U.DisplayName
    HAVING COUNT(DISTINCT T.TagName) > 1
    ORDER BY P.Score DESC, P.ViewCount DESC
    LIMIT 5
)
SELECT T.TagName,
       T.PostCount,
       U.DisplayName AS TopUser,
       U.TotalUpVotes,
       U.TotalDownVotes,
       U.BadgeCount,
       P.Title AS PopularPostTitle,
       P.Score AS PopularPostScore,
       P.ViewCount AS PopularPostViewCount
FROM TopTags T
JOIN TopUsers U ON U.UserRank <= 10
JOIN PopularPosts P ON P.Tags @> ARRAY[T.TagName]
ORDER BY T.PostCount DESC, U.TotalUpVotes DESC;
