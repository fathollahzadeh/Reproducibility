
WITH UserRankedVotes AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(v.Id) DESC) AS VoteRank
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
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(SUM(c.Score), 0) AS TotalComments,
        COUNT(DISTINCT pl.RelatedPostId) AS LinkedPostCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.TotalComments,
    pd.LinkedPostCount,
    COALESCE(pvs.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(pvs.DownVoteCount, 0) AS DownVoteCount,
    urr.TotalVotes AS UserVoteCount,
    urr.UpVotes AS UserUpVotes,
    (CASE 
        WHEN urr.UpVotes - urr.DownVotes >= 0 THEN 'Positive'
        ELSE 'Negative' 
    END) AS UserVoteSentiment,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = pd.PostId 
        AND v.UserId IS NOT NULL) AS UniqueVoterCount,
    (SELECT 
        MAX(v.CreationDate) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = pd.PostId 
        AND v.CreationDate IS NOT NULL) AS LastVoteDate
FROM 
    PostDetails pd
LEFT JOIN 
    PostVoteSummary pvs ON pd.PostId = pvs.PostId
LEFT JOIN 
    UserRankedVotes urr ON pd.OwnerUserId = urr.UserId
WHERE 
    pd.PostRank <= 5
ORDER BY 
    pd.LinkedPostCount DESC,
    pd.CreationDate DESC
LIMIT 10 OFFSET 0;
