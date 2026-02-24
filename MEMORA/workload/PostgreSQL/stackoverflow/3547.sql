
WITH UserVoteCounts AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(DISTINCT PostId) AS TotalVotes
    FROM Votes
    GROUP BY UserId
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RowNum
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate
), 
TagPostCounts AS (
    SELECT 
        t.Id AS TagId,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    COALESCE(upc.Upvotes, 0) AS UserUpvotes,
    COALESCE(upc.Downvotes, 0) AS UserDownvotes,
    COALESCE(tpc.PostCount, 0) AS TagsUsed,
    CASE 
        WHEN ps.RowNum <= 10 THEN 'Hot Post' 
        ELSE 'Regular Post' 
    END AS PostCategory
FROM PostStatistics ps
LEFT JOIN UserVoteCounts upc ON upc.UserId = ps.PostId
LEFT JOIN TagPostCounts tpc ON tpc.TagId = (SELECT MIN(Id) FROM Tags WHERE TagName IN (SELECT unnest(string_to_array(ps.Title, ' '))))
WHERE ps.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
ORDER BY ps.ViewCount DESC, ps.UpvoteCount DESC;
