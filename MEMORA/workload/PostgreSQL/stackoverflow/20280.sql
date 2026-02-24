
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(NULLIF(p.Body, ''), 'No content provided') AS PostBody
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (DATE '2024-10-01' - INTERVAL '2 years')
),
UserVoteSummary AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
VotesWithUserNames AS (
    SELECT 
        v.PostId,
        u.DisplayName AS VoterName,
        v.CreationDate,
        v.VoteTypeId,
        (CASE 
            WHEN v.VoteTypeId = 2 THEN 'Upvote'
            WHEN v.VoteTypeId = 3 THEN 'Downvote'
            ELSE 'Other'
        END) AS VoteType
    FROM 
        Votes v
    LEFT JOIN 
        Users u ON v.UserId = u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        COALESCE(c.Name, 'No Reason') AS CloseReasonName
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes c ON CAST(ph.Comment AS INT) = c.Id AND ph.PostHistoryTypeId = 10
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.ViewCount,
    rp.Score,
    rp.PostBody,
    SUM(u.UpVotesCount) AS TotalUpVotes,
    SUM(u.DownVotesCount) AS TotalDownVotes,
    COUNT(vwu.VoterName) AS TotalVoters,
    ARRAY_AGG(DISTINCT vwu.VoterName) AS VoterNames,
    STRING_AGG(DISTINCT CASE WHEN phd.PostHistoryTypeId = 10 
                              THEN phd.CloseReasonName 
                              ELSE NULL END, ', ') AS CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVoteSummary u ON rp.OwnerUserId = u.UserId
LEFT JOIN 
    VotesWithUserNames vwu ON rp.PostID = vwu.PostId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostID = phd.PostId
WHERE 
    rp.Rank <= 5
GROUP BY 
    rp.PostID, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.PostBody
HAVING 
    COUNT(DISTINCT vwu.VoterName) > 0 OR COUNT(DISTINCT phd.PostId) = 0
ORDER BY 
    rp.Score DESC NULLS LAST;
