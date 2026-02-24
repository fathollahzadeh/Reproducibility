WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate < cast('2024-10-01 12:34:56' as timestamp) AND
        p.ViewCount IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AcceptedAnswerId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    us.UpVotes,
    us.DownVotes,
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    CASE 
        WHEN pd.AcceptedAnswerId IS NOT NULL AND pd.AcceptedAnswerId <> -1 THEN 'Accepted Answer Exists'
        ELSE 'No Accepted Answer'
    END AS AcceptedAnswerStatus,
    CASE 
        WHEN pd.PostRank <= 3 THEN 'Top Post for User'
        ELSE 'Regular Post'
    END AS PostRankStatus
FROM 
    UserVoteSummary us
JOIN 
    Users u ON us.UserId = u.Id
LEFT JOIN 
    PostDetails pd ON u.Id = pd.PostId
WHERE 
    us.TotalVotes > 5
    AND (us.UpVotes - us.DownVotes) > 2 
ORDER BY 
    us.UpVotes DESC, 
    pd.ViewCount DESC
LIMIT 100;