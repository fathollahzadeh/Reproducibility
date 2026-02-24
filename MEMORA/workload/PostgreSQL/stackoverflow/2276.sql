WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
),
VoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
PostsWithVotes AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        VoteSummary vs ON tp.PostId = vs.PostId
),
FinalResults AS (
    SELECT 
        pwv.PostId,
        pwv.Title,
        pwv.Score,
        pwv.ViewCount,
        pwv.AnswerCount,
        pwv.UpVotes,
        pwv.DownVotes,
        CASE 
            WHEN pwv.UpVotes > pwv.DownVotes THEN 'Positive'
            WHEN pwv.UpVotes < pwv.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteStatus
    FROM 
        PostsWithVotes pwv
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    fr.ViewCount,
    fr.AnswerCount,
    fr.UpVotes,
    fr.DownVotes,
    fr.VoteStatus
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC NULLS LAST, 
    fr.ViewCount DESC NULLS LAST
LIMIT 20;