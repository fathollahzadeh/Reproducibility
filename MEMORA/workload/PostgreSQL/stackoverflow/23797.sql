WITH UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        AVG(COALESCE(c.Score, 0)) AS AvgCommentScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        QuestionsCount,
        AnswersCount,
        AvgCommentScore,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM UserReputation
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        pt.Name AS PostTypeName
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
PostScore AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.ViewCount,
        pu.Reputation AS OwnerReputation,
        COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS NetVotes
    FROM RecentPosts rp
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON rp.PostId = v.PostId
    LEFT JOIN Users pu ON rp.OwnerUserId = pu.Id
),
CombinedData AS (
    SELECT
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.ViewCount,
        ps.OwnerReputation,
        ps.NetVotes,
        tu.UserRank AS OwnerRank
    FROM PostScore ps
    JOIN TopUsers tu ON ps.OwnerUserId = tu.UserId
    WHERE ps.NetVotes > 0 AND ps.OwnerReputation > 100
)

SELECT 
    cd.Title,
    cd.CreationDate,
    cd.ViewCount,
    cd.OwnerReputation,
    cd.NetVotes,
    CASE 
        WHEN cd.OwnerRank IS NULL THEN 'Unranked'
        WHEN cd.OwnerRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory
FROM CombinedData cd
ORDER BY cd.NetVotes DESC, cd.ViewCount DESC
LIMIT 50;