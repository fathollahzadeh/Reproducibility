WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 
                 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteScore
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        ARRAY_AGG(DISTINCT ph.UserDisplayName) AS Editors
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) 
    GROUP BY 
        ph.PostId
),
CombinedData AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        COALESCE(pv.VoteScore, 0) AS VoteScore,
        COALESCE(ph.EditCount, 0) AS EditCount,
        ARRAY_LENGTH(ph.Editors, 1) AS UniqueEditorsCount,
        CASE 
            WHEN rp.AnswerCount > 0 THEN 'Answered'
            ELSE 'Unanswered'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVotes pv ON rp.Id = pv.PostId
    LEFT JOIN 
        PostHistories ph ON rp.Id = ph.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.CreationDate,
    cd.ViewCount,
    cd.VoteScore,
    cd.EditCount,
    cd.UniqueEditorsCount,
    cd.PostStatus,
    CASE 
        WHEN cd.VoteScore > 0 THEN 'Positive'
        WHEN cd.VoteScore < 0 THEN 'Negative'
        ELSE 'Neutral' 
    END AS VoteSentiment
FROM 
    CombinedData cd
WHERE 
    cd.VoteScore >= (SELECT AVG(VoteScore) FROM PostVotes)
ORDER BY 
    cd.ViewCount DESC, 
    cd.VoteScore DESC, 
    cd.EditCount DESC;