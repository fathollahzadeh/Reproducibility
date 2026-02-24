WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank,
        COALESCE(NULLIF(u.Reputation, 0), 1) AS Reputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - interval '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Reputation,
        RANK() OVER (ORDER BY rp.Score DESC) AS ScoreRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserRank = 1
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - interval '1 year'
    GROUP BY 
        v.PostId
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        tp.Reputation,
        tp.ScoreRank,
        pv.UpVotes,
        pv.DownVotes,
        (COALESCE(pv.UpVotes, 0) - COALESCE(pv.DownVotes, 0)) AS NetVotes,
        CASE 
            WHEN tp.ScoreRank <= 10 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostType
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostVotes pv ON tp.PostId = pv.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.AnswerCount,
    fp.Reputation,
    fp.ScoreRank,
    fp.UpVotes,
    fp.DownVotes,
    fp.NetVotes,
    fp.PostType
FROM 
    FinalResults fp
WHERE 
    fp.NetVotes > 0
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC;