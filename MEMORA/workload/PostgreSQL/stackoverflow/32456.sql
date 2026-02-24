WITH RecursivePostHistory AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM
        Posts p
    JOIN
        PostHistory ph ON p.Id = ph.PostId
    WHERE
        ph.PostHistoryTypeId IN (10, 11) 
),
AggregatedVotes AS (
    SELECT
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 1 THEN 1 END) AS AcceptedVotes
    FROM
        Votes
    GROUP BY
        PostId
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation,
        RANK() OVER (ORDER BY SUM(u.Reputation) DESC) AS UserRank
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
    HAVING
        SUM(u.Reputation) > 1000 
)
SELECT 
    ph.PostId,
    p.Title,
    COALESCE(av.UpVotes, 0) AS UpVotes,
    COALESCE(av.DownVotes, 0) AS DownVotes,
    COALESCE(av.AcceptedVotes, 0) AS AcceptedVotes,
    pu.DisplayName AS TopUser,
    pu.TotalReputation
FROM
    Posts p
LEFT JOIN
    RecursivePostHistory ph ON p.Id = ph.PostId AND ph.rn = 1 
LEFT JOIN
    AggregatedVotes av ON p.Id = av.PostId
LEFT JOIN
    TopUsers pu ON pu.UserRank <= 10 
WHERE
    ph.PostHistoryTypeId IS NULL OR ph.PostHistoryTypeId IN (11, 10) 
ORDER BY
    p.CreationDate DESC;