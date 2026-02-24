
WITH UserVotes AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT p.Id) AS PostsVotedOn
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotesCount,
        DownVotesCount,
        PostsVotedOn,
        ROW_NUMBER() OVER (ORDER BY UpVotesCount DESC) AS Rnk
    FROM 
        UserVotes
    WHERE 
        PostsVotedOn > 10
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.UpVotesCount,
    t.DownVotesCount,
    (t.UpVotesCount - t.DownVotesCount) AS NetVotes,
    ph.TotalPostHistoryCount,
    MAX(ph.MostRecentEditDate) AS MostRecentEdit
FROM 
    TopUsers t
JOIN 
    (SELECT 
         ph.UserId, 
         COUNT(*) AS TotalPostHistoryCount,
         MAX(ph.CreationDate) AS MostRecentEditDate
     FROM 
         PostHistory ph
     GROUP BY 
         ph.UserId
    ) ph ON t.UserId = ph.UserId
WHERE 
    t.Rnk <= 10
GROUP BY 
    t.UserId, t.DisplayName, t.UpVotesCount, t.DownVotesCount, ph.TotalPostHistoryCount
ORDER BY 
    NetVotes DESC;
