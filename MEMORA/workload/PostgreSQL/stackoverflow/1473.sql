WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS Rank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        RANK() OVER (ORDER BY SUM(p.ViewCount) DESC) AS UserRank
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY u.Id, u.DisplayName
)
SELECT
    u.DisplayName AS TopUser,
    u.TotalViews,
    rp.Title AS TopPostTitle,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes
FROM TopUsers u
JOIN RankedPosts rp ON u.UserId = rp.PostId
WHERE u.UserRank <= 5 AND rp.Rank = 1
ORDER BY u.TotalViews DESC, rp.UpVotes DESC
FETCH FIRST 10 ROWS ONLY;