
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        AnswerCount, 
        CommentCount, 
        Author
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 10
), 
PostVoteSummary AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.Author,
    COALESCE(ps.UpVotes, 0) AS TotalUpVotes,
    COALESCE(ps.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN COALESCE(ps.UpVotes, 0) + COALESCE(ps.DownVotes, 0) > 0 THEN 
            (COALESCE(ps.UpVotes, 0) * 1.0 / (COALESCE(ps.UpVotes, 0) + COALESCE(ps.DownVotes, 0))) * 100 
        ELSE 0 END AS UpVotePercentage
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteSummary ps ON tp.PostId = ps.PostId
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
