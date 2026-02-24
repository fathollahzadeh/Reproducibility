WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        COUNT(a.Id) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS RankByUpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.Tags
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Author,
        rp.TotalAnswers,
        rp.UpVotes,
        rp.DownVotes,
        rp.RankByUpVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByUpVotes <= 10 
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.Tags,
    tp.Author,
    tp.TotalAnswers,
    tp.UpVotes,
    tp.DownVotes,
    (tp.UpVotes - tp.DownVotes) AS NetVotes,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = tp.PostId AND ph.PostHistoryTypeId = 10) AS CloseCount, 
    (SELECT STRING_AGG(Name, ', ') FROM Badges b WHERE b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)) AS UserBadges
FROM 
    TopPosts tp
ORDER BY 
    tp.RankByUpVotes, tp.UpVotes DESC;