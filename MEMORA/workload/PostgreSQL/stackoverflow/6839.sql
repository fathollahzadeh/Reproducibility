
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY ViewCount DESC, UpVotes DESC) AS PopularityRank
    FROM 
        RankedPosts
    WHERE 
        rn = 1
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE(bt.Name, 'No Badge') AS Badge,
    u.DisplayName AS OwnerDisplayName
FROM 
    TopPosts tp
LEFT JOIN 
    Users u ON tp.PostId = u.Id
LEFT JOIN 
    Badges bt ON u.Id = bt.UserId AND bt.Date >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
WHERE 
    tp.PopularityRank <= 10
ORDER BY 
    tp.PopularityRank;
