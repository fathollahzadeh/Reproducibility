WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
),
PostDetails AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Tags,
        rp.Author,
        ph.Comment AS LastEditComment,
        ph.CreationDate AS LastEditDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId
    WHERE 
        ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = rp.PostId)
        AND ph.PostHistoryTypeId IN (4, 5, 6) 
),
VoteSummary AS (
    SELECT
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
FinalResults AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Tags,
        pd.Author,
        pd.LastEditComment,
        pd.LastEditDate,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes
    FROM 
        PostDetails pd
    LEFT JOIN 
        VoteSummary vs ON pd.PostId = vs.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Tags,
    Author,
    LastEditComment,
    LastEditDate,
    UpVotes,
    DownVotes
FROM 
    FinalResults
WHERE 
    UpVotes > DownVotes 
ORDER BY 
    CreationDate DESC;