WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.ClosedDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
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
        rp.AnswerCount,
        COALESCE(pht.Dto, 0) AS TotalEdits,
        COALESCE(pb.BountyAmount, 0) AS BountyAmount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS Dto 
        FROM 
            PostHistory 
        WHERE 
            PostHistoryTypeId IN (5, 6, 24) 
        GROUP BY 
            PostId
    ) pht ON rp.PostId = pht.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(BountyAmount) AS BountyAmount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId IN (8, 9) 
        GROUP BY 
            PostId
    ) pb ON rp.PostId = pb.PostId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    CASE 
        WHEN tp.TotalEdits > 0 THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus,
    CASE 
        WHEN tp.BountyAmount > 0 THEN 'Has Bounty'
        ELSE 'No Bounty'
    END AS BountyStatus,
    COALESCE(ut.UserIds, 'No users') AS VoterUsers,
    COALESCE(ut.VoteCount, 0) AS TotalVotes
FROM 
    TopPosts tp
LEFT JOIN (
    SELECT 
        PostId,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS UserIds,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    JOIN 
        Users u ON v.UserId = u.Id
    GROUP BY 
        v.PostId
) ut ON tp.PostId = ut.PostId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;