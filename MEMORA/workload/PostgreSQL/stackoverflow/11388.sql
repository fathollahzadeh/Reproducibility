
WITH PostCounts AS (
    SELECT
        CAST(CreationDate AS DATE) AS PostDate,
        COUNT(*) AS TotalPosts
    FROM
        Posts
    GROUP BY
        CAST(CreationDate AS DATE)
),
UserCounts AS (
    SELECT
        CAST(CreationDate AS DATE) AS UserDate,
        COUNT(*) AS TotalUsers
    FROM
        Users
    GROUP BY
        CAST(CreationDate AS DATE)
),
VoteCounts AS (
    SELECT
        CAST(CreationDate AS DATE) AS VoteDate,
        COUNT(*) AS TotalVotes
    FROM
        Votes
    GROUP BY
        CAST(CreationDate AS DATE)
)
SELECT
    COALESCE(p.PostDate, u.UserDate, v.VoteDate) AS ActivityDate,
    COALESCE(p.TotalPosts, 0) AS Posts,
    COALESCE(u.TotalUsers, 0) AS Users,
    COALESCE(v.TotalVotes, 0) AS Votes
FROM
    PostCounts p
FULL OUTER JOIN
    UserCounts u ON p.PostDate = u.UserDate
FULL OUTER JOIN
    VoteCounts v ON COALESCE(p.PostDate, u.UserDate) = v.VoteDate
ORDER BY
    ActivityDate;
