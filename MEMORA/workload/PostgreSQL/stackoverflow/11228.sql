WITH UserStatistics AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.Reputation, u.Views, u.UpVotes, u.DownVotes
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        Views,
        UpVotes,
        DownVotes,
        PostCount,
        TotalBountyAmount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, Reputation DESC) AS Rank
    FROM UserStatistics
)
SELECT 
    UserId,
    Reputation,
    Views,
    UpVotes,
    DownVotes,
    PostCount,
    TotalBountyAmount
FROM TopUsers
WHERE Rank <= 10;