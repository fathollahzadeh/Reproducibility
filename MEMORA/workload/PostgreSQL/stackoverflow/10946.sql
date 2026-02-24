WITH PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.Id AS OwnerUserId,
        u.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
),
VoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 6 OR VoteTypeId = 10 THEN 1 END) AS CloseVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
CommentCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
),
FinalResults AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.Score,
        pa.ViewCount,
        pa.AnswerCount,
        pa.CommentCount,
        pa.FavoriteCount,
        pa.OwnerUserId,
        pa.OwnerReputation,
        pa.OwnerDisplayName,
        COALESCE(vc.UpVotes, 0) AS UpVotes,
        COALESCE(vc.DownVotes, 0) AS DownVotes,
        COALESCE(vc.CloseVotes, 0) AS CloseVotes,
        COALESCE(cc.TotalComments, 0) AS TotalComments
    FROM 
        PostActivity pa
    LEFT JOIN 
        VoteCounts vc ON pa.PostId = vc.PostId
    LEFT JOIN 
        CommentCounts cc ON pa.PostId = cc.PostId
)

SELECT 
    *,
    (UpVotes - DownVotes) AS VoteBalance,
    (Score + UpVotes - DownVotes + TotalComments) AS EngagementScore
FROM 
    FinalResults
ORDER BY 
    EngagementScore DESC
LIMIT 100;