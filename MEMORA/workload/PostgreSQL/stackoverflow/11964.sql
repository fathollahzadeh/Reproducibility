WITH UserPostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserVoteCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        UserId
),
PostCommentCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UPC.PostCount, 0) AS TotalPosts,
    COALESCE(UVC.VoteCount, 0) AS TotalVotes,
    COALESCE(PCC.CommentCount, 0) AS TotalComments
FROM 
    Users U
LEFT JOIN 
    UserPostCounts UPC ON U.Id = UPC.OwnerUserId
LEFT JOIN 
    UserVoteCounts UVC ON U.Id = UVC.UserId
LEFT JOIN 
    PostCommentCounts PCC ON U.Id = PCC.PostId
ORDER BY 
    TotalPosts DESC, TotalVotes DESC;