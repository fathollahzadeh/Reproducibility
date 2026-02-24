WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.PostRank = 1
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostWithVotes AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN COALESCE(pvc.UpVotes, 0) > COALESCE(pvc.DownVotes, 0) THEN 'Positive'
            WHEN COALESCE(pvc.UpVotes, 0) < COALESCE(pvc.DownVotes, 0) THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostVoteCounts pvc ON tp.PostId = pvc.PostId
),
PostsWithComments AS (
    SELECT 
        pwv.PostId,
        pwv.Title,
        pwv.CreationDate,
        pwv.UpVotes,
        pwv.DownVotes,
        pwv.VoteSentiment,
        COUNT(c.Id) AS CommentCount
    FROM 
        PostWithVotes pwv
    LEFT JOIN 
        Comments c ON pwv.PostId = c.PostId
    GROUP BY 
        pwv.PostId, pwv.Title, pwv.CreationDate, pwv.UpVotes, pwv.DownVotes, pwv.VoteSentiment
)
SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.CreationDate,
    pwc.UpVotes,
    pwc.DownVotes,
    pwc.VoteSentiment,
    pwc.CommentCount,
    CASE 
        WHEN pwc.CommentCount > 10 THEN 'Hot'
        WHEN pwc.CommentCount > 0 THEN 'Active'
        ELSE 'Silent'
    END AS ActivityLevel
FROM 
    PostsWithComments pwc
WHERE 
    pwc.UpVotes IS NOT NULL
ORDER BY 
    pwc.UpVotes DESC, pwc.CreationDate DESC;