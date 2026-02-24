WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(v.Id) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
HighRepPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts AS p
    WHERE 
        p.Score >= 50
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        p.OwnerDisplayName,
        COALESCE(ph.Comment, 'No Comment') AS ActionComment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
),
AggregatedHistory AS (
    SELECT 
        phd.PostId,
        STRING_AGG(DISTINCT phd.ActionComment, '; ') AS ConcatenatedComments,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistoryDetails phd
    GROUP BY 
        phd.PostId
)
SELECT 
    uvs.UserId,
    uvs.DisplayName,
    uvs.TotalVotes,
    uvs.UpVotes,
    uvs.DownVotes,
    (SELECT COUNT(*) FROM HighRepPosts h WHERE h.OwnerUserId = uvs.UserId) AS HighRepPostCount,
    CASE 
        WHEN (SELECT COUNT(*) FROM HighRepPosts h WHERE h.OwnerUserId = uvs.UserId) = 0 
        THEN 'No High Reputation Posts'
        ELSE 'Has High Reputation Posts'
    END AS HighRepPostStatus,
    ah.PostId,
    ah.ConcatenatedComments,
    ah.HistoryCount
FROM 
    UserVoteStats uvs
LEFT JOIN 
    AggregatedHistory ah ON uvs.UserId = ah.PostId
ORDER BY 
    uvs.Rank, uvs.TotalVotes DESC NULLS LAST;