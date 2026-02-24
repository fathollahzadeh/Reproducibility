WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
TopUsers AS (
    SELECT UserId 
    FROM UserReputation 
    WHERE Rank <= 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(c.Count, 0) AS CommentCount,
        COALESCE(v.UpVoteCount, 0) AS UpVotes,
        COALESCE(v.DownVoteCount, 0) AS DownVotes,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
            ELSE 'No' 
        END AS IsAccepted
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS Count 
        FROM Comments 
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    WHERE p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year' 
          AND p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        pd.IsAccepted,
        RANK() OVER (ORDER BY (pd.UpVotes - pd.DownVotes) DESC) AS PostRank
    FROM PostDetails pd
    WHERE pd.CommentCount > 5
)

SELECT 
    u.DisplayName,
    tp.Title,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.IsAccepted
FROM 
    TopUsers tu
JOIN 
    Users u ON tu.UserId = u.Id
JOIN 
    Posts p ON u.Id = p.OwnerUserId
JOIN 
    TopPosts tp ON p.Id = tp.PostId
WHERE 
    tp.PostRank <= 5
ORDER BY 
    u.Reputation DESC, tp.UpVotes - tp.DownVotes DESC;