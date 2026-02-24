
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(a.Body, 'No accepted answer') AS AcceptedAnswerBody,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, a.Body, p.OwnerUserId
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        CASE 
            WHEN u.LastAccessDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' THEN 'Inactive'
            ELSE 'Active'
        END AS UserStatus
    FROM 
        Users u
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.AcceptedAnswerBody,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    ud.DisplayName AS UserDisplayName,
    ud.Reputation,
    ud.UserStatus,
    pd.UserPostRank
FROM 
    PostDetails pd
JOIN 
    Users u ON pd.UserPostRank = 1 AND u.Id = pd.UserPostRank
JOIN 
    UserDetails ud ON u.Id = ud.UserId
WHERE 
    pd.CommentCount > 5
ORDER BY 
    pd.UpVotes DESC, pd.CreationDate DESC
LIMIT 10 OFFSET 5;
