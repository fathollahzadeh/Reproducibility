
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(c.Id) AS TotalComments
    FROM
        Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    LEFT JOIN Comments c ON c.UserId = u.Id
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        ua.UserId,
        ua.DisplayName,
        ua.TotalUpVotes - ua.TotalDownVotes AS NetVotes,
        RANK() OVER (ORDER BY ua.TotalUpVotes DESC) AS UserRank
    FROM
        UserActivity ua
    WHERE
        ua.TotalUpVotes > 0
)
SELECT
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Rank,
    tu.DisplayName AS TopUser,
    tu.NetVotes,
    rp.Score AS PostScore,
    ARRAY_LENGTH(string_to_array(rp.Tags, '><'), 1) AS TagCount
FROM
    RankedPosts rp
JOIN
    TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE
    rp.Rank = 1
ORDER BY
    rp.CreationDate DESC
LIMIT 10;
