WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
AcceptedAnswers AS (
    SELECT 
        p.Id AS AnswerId,
        p.AcceptedAnswerId,
        u.DisplayName AS AnswererDisplayName,
        p.Score AS AnswerScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
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
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    COALESCE(pa.AnswererDisplayName, 'No accepted answer') AS AcceptedAnswerUser,
    pa.AnswerScore AS AcceptedAnswerScore,
    pv.VoteCount,
    pv.UpVoteCount,
    pv.DownVoteCount,
    CASE 
        WHEN pv.VoteCount = 0 THEN 'No votes'
        WHEN pv.UpVoteCount > pv.DownVoteCount THEN 'More Upvotes'
        ELSE 'More Downvotes'
    END AS VoteSummary
FROM 
    RankedPosts rp
LEFT JOIN 
    AcceptedAnswers pa ON rp.Id = pa.AcceptedAnswerId
LEFT JOIN 
    PostVotes pv ON rp.Id = pv.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC
LIMIT 50;